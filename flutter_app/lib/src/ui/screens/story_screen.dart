import 'package:flutter/material.dart';

import '../theme/neon_theme.dart';
import '../widgets/animated_grid_background.dart';
import '../widgets/epic_neon_button.dart';
import '../widgets/epic_neon_title.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  static const List<_StoryChapter> _chapters = [
    _StoryChapter(
      title: 'The Flicker Nations',
      subtitle: 'A neon skyline on the edge of collapse.',
      beats: [
        '2141—after the Resonance Event severed the Central Grid, every megastructure flickers between light and silence.',
        'You are Commander Lira Kestrel of the Aegis Vanguard, sent into the ruined sectors to re-ignite stability and buy time for the remaining cities.',
        'Each tower you deploy anchors a shard of power into the fracturing grid, and every enemy wave is a corrupted synth-swarm hungry for your light.',
      ],
      accent: NeonColors.cyan,
    ),
    _StoryChapter(
      title: 'The Pulse Accord',
      subtitle: 'Forged between science and sorcery.',
      beats: [
        'The Neon Pulse ability is more than a weapon—it is the ancient waveform of the old Grid, cleansed and reshaped by the Phase Mages.',
        'Mines are celestial anchors: when armed, they hum in the key of Aether and explode in kaleidoscopic cascades that rip holes through the static.',
        'As you progress, the Accord’s holographic sages narrate instructions, unlocking new rites and upgraded towers in exchange for living energy.',
      ],
      accent: NeonColors.magenta,
    ),
    _StoryChapter(
      title: 'Waves of the Fallen',
      subtitle: 'Overload, Juggernaut, Phantom—their names echo in the tunnel cores.',
      beats: [
        'Overload waves are the corrupted couriers of the Syndicate, arriving in bursts of hyperspeed that force you to mesh lightning-fast towers.',
        'Juggernauts clank across the broken sidewalks, their armor plated in forgotten currencies, slowing your pulse with every stomp.',
        'Phantoms slip through emitted light, detected only by the Phase Mage’s arcane shimmer—if they reach the Core, they siphon the very story you fight to preserve.',
      ],
      accent: NeonColors.yellow,
    ),
    _StoryChapter(
      title: 'Renegade Beacon',
      subtitle: 'Every victory plants a beacon of hope.',
      beats: [
        'The Level Select interface is your orbital map; each cleared stage unlocks a new beacon, a reference point for the fleeing citizens.',
        'Stars track your lives and how elegantly you danced through the storm—perfect clears send ripples of light down the Aegis lines.',
        'In the final arc, the Grid itself starts singing. Hold it together, and a new dawn blooms beyond the data horizon.',
      ],
      accent: NeonColors.green,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                  'Every tower is a promise. Every wave is a prophecy being rewritten.',
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
                      return _StoryCard(chapter: chapter);
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
    required this.title,
    required this.subtitle,
    required this.beats,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<String> beats;
  final Color accent;
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.chapter});

  final _StoryChapter chapter;

  @override
  Widget build(BuildContext context) {
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
                chapter.title,
                style: NeonTextStyles.title.copyWith(
                  fontSize: 22,
                  color: chapter.accent,
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
                      chapter.accent,
                      chapter.accent.withOpacity(0.3),
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
              color: NeonColors.white.withOpacity(0.7),
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
                        color: chapter.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        beat,
                        style: NeonTextStyles.body.copyWith(
                          color: NeonColors.white.withOpacity(0.8),
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
