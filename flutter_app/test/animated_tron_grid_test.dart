import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/models/level_config.dart';
import 'package:bored_games/src/services/level_service.dart';
import 'package:bored_games/src/ui/screens/level_select_screen.dart';
import 'package:bored_games/src/ui/widgets/animated_tron_grid.dart';

void main() {
  setUp(() {
    LevelService.overrideUnlockAllLevels = true;
  });

  tearDown(() {
    LevelService.overrideUnlockAllLevels = null;
  });

  testWidgets('AnimatedTronGrid calls onSelectLevel when tapped', (tester) async {
    final levels = [
      const LevelConfig(
        id: 1,
        name: 'Level 1',
        mapFile: 'maps/level1.tmx',
        waves: 5,
        difficulty: 1,
      ),
      const LevelConfig(
        id: 2,
        name: 'Level 2',
        mapFile: 'maps/level2.tmx',
        waves: 6,
        difficulty: 1,
      ),
      const LevelConfig(
        id: 3,
        name: 'Level 3',
        mapFile: 'maps/level3.tmx',
        waves: 7,
        difficulty: 2,
      ),
    ];
    const world = WorldInfo(
      id: 1,
      name: 'Test World',
      tagline: 'Test',
      accent: Colors.cyan,
    );
    int? selectedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: AnimatedTronGrid(
                world: world,
                levels: levels,
                levelService: LevelService.instance,
                selectedLevelId: null,
                onSelectLevel: (id) => selectedId = id,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final gridFinder = find.byType(AnimatedTronGrid);
    final box = tester.renderObject<RenderBox>(gridFinder);
    final size = box.size;
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = math.min(size.width, size.height) * 0.35;
    final angle = -math.pi / 2;
    final target = Offset(
      center.dx + orbitRadius * math.cos(angle),
      center.dy + orbitRadius * math.sin(angle),
    );

    await tester.tapAt(box.localToGlobal(target));
    await tester.pump();

    expect(selectedId, levels.first.id);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
