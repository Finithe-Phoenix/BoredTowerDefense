import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../services/level_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/animated_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';
import '../widgets/glitch_text.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  static const int _levelsPerWorld = 10;

  static const List<_StoryChapter> _chapters = [
    _StoryChapter(
      worldId: 1,
      title: 'NEON FRONTIER',
      subtitle: 'ERROR_01: EL ORIGEN DEL VACÍO',
      imagePath: 'assets/images/story_frontier.png',
      beats: [
        'El "Decompiler" ha perforado el Sector 0. La realidad digital se desmorona en fragmentos de ruido.',
        'Como el Arquitecto, tu misión es anclar la red antes de que la corrupción sea irreversible.',
        'Cada torre es un cortafuegos. Cada disparo, una línea de código recuperada.',
      ],
      accent: NeonColors.cyan,
    ),
    _StoryChapter(
      worldId: 2,
      title: 'RIFT WARS',
      subtitle: 'ERROR_02: CASCADA DE MEMORIA',
      imagePath: 'assets/images/story_rifts.png',
      beats: [
        'El virus ha creado anomalías temporales. Los datos del pasado se filtran en el presente.',
        'Las grietas de energía magenta son cicatrices en la malla. Debes sellarlas con pura potencia de fuego.',
        'El ruido se vuelve más denso. La red grita pidiendo restauración.',
      ],
      accent: NeonColors.magenta,
    ),
    _StoryChapter(
      worldId: 3,
      title: 'SIGNAL WASTES',
      subtitle: 'ERROR_03: ECO EN EL VACÍO',
      imagePath: 'assets/images/story_wastes.png',
      beats: [
        'Desiertos de estática donde la señal muere. El Decompiler acecha en las sombras del código.',
        'Sin visibilidad total, las torres son faros en una tormenta de bits perdidos.',
        'Si la luz se apaga aquí, el Grid caerá en el silencio eterno.',
      ],
      accent: NeonColors.yellow,
    ),
    _StoryChapter(
      worldId: 4,
      title: 'ION CROWN',
      subtitle: 'ERROR_04: LA CORONA DE TORMENTA',
      imagePath: 'assets/images/story_crown.png',
      beats: [
        'La última línea de defensa antes del Núcleo Central. Tormentas iónicas azotan la infraestructura.',
        'El enemigo ha movilizado a sus unidades de asedio más pesadas. El tiempo de corrección se agota.',
        'Solo una voluntad de hierro puede sostener la corona de energía.',
      ],
      accent: NeonColors.green,
    ),
    _StoryChapter(
      worldId: 5,
      title: 'SHARD VAULT',
      subtitle: 'ERROR_05: MEMORIAS CORRUPTAS',
      beats: [
        'Bóvedas de seguridad donde se guardan las funciones raíz. El virus intenta borrarlas para siempre.',
        'Recupera los fragmentos de memoria. Evoluciona tus sistemas. No permitas que el pasado desaparezca.',
      ],
      accent: NeonColors.red,
    ),
    _StoryChapter(
      worldId: 10,
      title: 'FINAL GATE',
      subtitle: 'SYS_FINAL: EL ÚLTIMO UMBRAL',
      beats: [
        'Todo converger al Núcleo. El Decompiler está materializando su forma final.',
        'Si la Puerta Final cae, el sistema entero será formateado al Vacío.',
        'Es hora de ejecutar la secuencia final. Por el Grid.',
      ],
      accent: NeonColors.white,
    ),
  ];

  int _worldForLevel(int levelId) => ((levelId - 1) ~/ _levelsPerWorld) + 1;

  List<LevelConfig> _levelsForWorld(LevelService service, int worldId) {
    return service.levels
        .where((level) => _worldForLevel(level.id) == worldId)
        .toList(growable: false);
  }

  _WorldProgress _worldProgress(LevelService service, int worldId) {
    final levels = _levelsForWorld(service, worldId);
    int completed = 0;
    bool unlocked = false;
    for (final level in levels) {
      if (service.isLevelUnlocked(level.id)) {
        unlocked = true;
      }
      if (service.getProgress(level.id).completed) {
        completed += 1;
      }
    }
    return _WorldProgress(
      total: levels.length,
      completed: completed,
      unlocked: unlocked || worldId == 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelService = LevelService.instance;
    return Scaffold(
      body: AnimatedGridBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const EpicNeonTitle(
                  text: 'THE ARCHITECT LOGS',
                  fontSize: 38,
                  primaryColor: NeonColors.white,
                  secondaryColor: NeonColors.cyan,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: NeonColors.cyan.withOpacity(0.1),
                    border: Border.all(color: NeonColors.cyan.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.security, color: NeonColors.cyan, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlitchText(
                          text: 'ESTADO DEL SISTEMA: CRÍTICO - RECURSIVE_DECOMPILE_DETECTED',
                          style: NeonTextStyles.small.copyWith(color: NeonColors.cyan, fontSize: 10),
                          duration: const Duration(seconds: 3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _chapters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final chapter = _chapters[index];
                      final progress = _worldProgress(levelService, chapter.worldId);
                      return _StoryCard(chapter: chapter, progress: progress);
                    },
                  ),
                ),
                EpicNeonButton(
                  text: 'RETURN TO MENU',
                  icon: Icons.arrow_back_rounded,
                  color: NeonColors.cyan,
                  width: 220,
                  height: 48,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryChapter {
  const _StoryChapter({
    required this.worldId,
    required this.title,
    required this.subtitle,
    required this.beats,
    required this.accent,
    this.imagePath,
  });

  final int worldId;
  final String title;
  final String subtitle;
  final List<String> beats;
  final Color accent;
  final String? imagePath;
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.chapter, required this.progress});

  final _StoryChapter chapter;
  final _WorldProgress progress;

  String get _statusLabel {
    if (!progress.unlocked) return 'LOCKED';
    if (progress.total > 0 && progress.completed >= progress.total) {
      return 'CLEARED';
    }
    if (progress.completed > 0) return 'IN PROGRESS';
    return 'UNLOCKED';
  }

  Color get _statusColor {
    if (!progress.unlocked) return NeonColors.red;
    if (progress.total > 0 && progress.completed >= progress.total) {
      return NeonColors.green;
    }
    if (progress.completed > 0) return NeonColors.cyan;
    return NeonColors.magenta;
  }

  @override
  Widget build(BuildContext context) {
    final opacity = progress.unlocked ? 1.0 : 0.55;
    final progressRatio =
        progress.total == 0 ? 0.0 : progress.completed / progress.total;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: NeonColors.surfaceBg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chapter.accent.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: chapter.accent.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chapter.imagePath != null && progress.unlocked)
            Stack(
              children: [
                Image.asset(
                  chapter.imagePath!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 140,
                    color: chapter.accent.withOpacity(0.1),
                    child: Center(
                      child: Icon(Icons.image_not_supported, color: chapter.accent),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          NeonColors.surfaceBg.withOpacity(0.2),
                          NeonColors.surfaceBg,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                   top: 12,
                   right: 12,
                   child: Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       color: Colors.black54,
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Icon(Icons.emergency_recording_rounded, color: chapter.accent, size: 16),
                   ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'WORLD ${chapter.worldId}',
                      style: NeonTextStyles.small.copyWith(
                        color: chapter.accent.withOpacity(0.85),
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _statusColor.withOpacity(0.6)),
                      ),
                      child: Text(
                        _statusLabel,
                        style: NeonTextStyles.small.copyWith(
                          color: _statusColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${progress.completed}/${progress.total} NODES',
                      style: NeonTextStyles.small.copyWith(
                        color: NeonColors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressRatio.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            chapter.accent.withOpacity(0.9),
                            chapter.accent.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: chapter.accent.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GlitchText(
                      text: chapter.title,
                      style: NeonTextStyles.title.copyWith(
                        fontSize: 22,
                        color: chapter.accent.withOpacity(opacity),
                        letterSpacing: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            chapter.accent.withOpacity(opacity),
                            chapter.accent.withOpacity(0.3 * opacity),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  chapter.subtitle,
                  style: NeonTextStyles.body.copyWith(
                    color: NeonColors.white.withOpacity(0.7 * opacity),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...chapter.beats.map((beat) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: chapter.accent.withOpacity(opacity),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              beat,
                              style: NeonTextStyles.body.copyWith(
                                color: NeonColors.white.withOpacity(0.8 * opacity),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldProgress {
  const _WorldProgress({
    required this.total,
    required this.completed,
    required this.unlocked,
  });

  final int total;
  final int completed;
  final bool unlocked;
}
