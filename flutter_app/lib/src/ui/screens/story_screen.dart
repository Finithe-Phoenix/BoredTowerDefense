import 'package:flutter/material.dart';

import '../../models/level_config.dart';
import '../../services/level_service.dart';
import '../theme/neon_theme.dart';
import '../widgets/animated_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  static const int _levelsPerWorld = 10;

  static const List<_StoryChapter> _chapters = [
    _StoryChapter(
      worldId: 1,
      title: 'Neon Frontier',
      subtitle: 'Capitulo 1 - La primera chispa.',
      beats: [
        'El Evento Resonancia apago la red central y las ciudades quedaron en modo supervivencia.',
        'Eres la comandante Lira Kestrel, enviada a reactivar nodos y sostener la linea.',
        'Cada torre ancla energia y corta el avance del ruido corrupto.',
      ],
      accent: NeonColors.cyan,
    ),
    _StoryChapter(
      worldId: 2,
      title: 'Rift Wars',
      subtitle: 'Capitulo 2 - Grietas en la malla.',
      beats: [
        'Las grietas abren rutas nuevas y los enjambres se filtran a velocidad rift.',
        'Tus pulsos reescriben el flujo y las minas sellan pasos inestables.',
        'La vanguardia mantiene el pulso mientras la historia se fractura.',
      ],
      accent: NeonColors.magenta,
    ),
    _StoryChapter(
      worldId: 3,
      title: 'Signal Wastes',
      subtitle: 'Capitulo 3 - Silencio y eco.',
      beats: [
        'Los desiertos de senal rompen el ritmo y obligan a defender pasillos largos.',
        'Los enemigos aprenden a ocultarse en el vacio; tu vision debe ser total.',
        'Si sostienes la luz, la red responde con fuerza renovada.',
      ],
      accent: NeonColors.yellow,
    ),
    _StoryChapter(
      worldId: 4,
      title: 'Ion Crown',
      subtitle: 'Capitulo 4 - La corona de tormenta.',
      beats: [
        'Tormentas ionicas recortan los carriles y obligan a cerrar brechas rapido.',
        'Las oleadas pesan mas; cada decision define el pulso del mundo.',
        'Sobrevivir aqui es ganar tiempo para que el Grid vuelva a latir.',
      ],
      accent: NeonColors.green,
    ),
    _StoryChapter(
      worldId: 5,
      title: 'Shard Vault',
      subtitle: 'Capitulo 5 - La memoria perdida.',
      beats: [
        'Las bovedas antiguas guardan codigos de mejora y secretos de combate.',
        'Tus torres absorben fragmentos de memoria y evolucionan en pleno asedio.',
        'Cada nivel limpiado libera un nodo del pasado.',
      ],
      accent: NeonColors.red,
    ),
    _StoryChapter(
      worldId: 6,
      title: 'Arc Fortress',
      subtitle: 'Capitulo 6 - El asedio.',
      beats: [
        'La fortaleza concentra ataques y obliga a defender multiples frentes.',
        'Las oleadas llegan mas compactas; el control del mapa es vital.',
        'Solo la disciplina mantiene la linea de Aegis.',
      ],
      accent: NeonColors.purple,
    ),
    _StoryChapter(
      worldId: 7,
      title: 'Core Hunt',
      subtitle: 'Capitulo 7 - Caza al nucleo.',
      beats: [
        'El enemigo ignora todo menos el nucleo; cada error cuesta caro.',
        'La precision manda: pulsa, mina y enfoca cada disparo.',
        'El Grid tiembla, pero no se rinde.',
      ],
      accent: NeonColors.orange,
    ),
    _StoryChapter(
      worldId: 8,
      title: 'Omega Grid',
      subtitle: 'Capitulo 8 - Bucle infinito.',
      beats: [
        'El Omega Grid repite patrones y castiga a quien no se adapta.',
        'La presion es constante; solo la estrategia rompe el ciclo.',
        'Cada victoria escribe una ruta nueva en la red.',
      ],
      accent: NeonColors.blue,
    ),
    _StoryChapter(
      worldId: 9,
      title: 'Storm Tower',
      subtitle: 'Capitulo 9 - El filo del rayo.',
      beats: [
        'Los corredores se fracturan y el tiempo se vuelve enemigo.',
        'Los rayos marcan el ritmo; tus torres deben responder al instante.',
        'La vanguardia empieza a ver la salida.',
      ],
      accent: NeonColors.cyan,
    ),
    _StoryChapter(
      worldId: 10,
      title: 'Final Gate',
      subtitle: 'Capitulo 10 - El ultimo umbral.',
      beats: [
        'La ultima puerta resiste con su ultima energia.',
        'Si la mantienes en pie, el Grid renace.',
        'Un nuevo amanecer espera al otro lado del ruido.',
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
                  text: 'STORY MODE',
                  fontSize: 42,
                  primaryColor: NeonColors.white,
                  secondaryColor: NeonColors.magenta,
                ),
                const SizedBox(height: 8),
                Text(
                  'La historia avanza con cada mundo. Cada victoria enciende un nodo mas.',
                  textAlign: TextAlign.center,
                  style: NeonTextStyles.body.copyWith(
                    color: NeonColors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
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
  });

  final int worldId;
  final String title;
  final String subtitle;
  final List<String> beats;
  final Color accent;
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
      padding: const EdgeInsets.all(16),
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
              Text(
                chapter.title,
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
