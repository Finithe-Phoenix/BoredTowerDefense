import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/data/story_data.dart';

void main() {
  test('story data lookups return expected entries', () {
    final world = StoryData.worlds.first;
    expect(world.id, 1);
    expect(StoryData.getCinematic('prologue'), isNotNull);
    expect(StoryData.getCinematic('missing'), isNull);
    expect(StoryData.getEnemyProfile('runner'), isNotNull);
    expect(StoryData.getEnemyProfile('missing'), isNull);
  });

  test('memory fragments unlock by level', () {
    final low = StoryData.getUnlockedMemories(1);
    final mid = StoryData.getUnlockedMemories(20);
    final high = StoryData.getUnlockedMemories(100);

    expect(low.isNotEmpty, isTrue);
    expect(mid.length >= low.length, isTrue);
    expect(high.length >= mid.length, isTrue);
  });

  test('lore category names are non-empty', () {
    for (final category in LoreCategory.values) {
      final entry = LoreEntry(
        id: 'id',
        title: 'title',
        category: category,
        content: 'content',
        unlockLevel: 1,
        accentColor: const Color(0xFF000000),
      );
      expect(entry.categoryName.isNotEmpty, isTrue);
    }
  });
}
