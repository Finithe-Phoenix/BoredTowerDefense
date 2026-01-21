import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/services/sprite_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize caches common colors and returns sprites', (tester) async {
    final service = SpriteCacheService.instance;
    await service.initialize();

    expect(service.isInitialized, isTrue);

    const commonColor = Color(0xFF00FFFF);
    expect(service.getProjectileSprite(commonColor), isNotNull);
    expect(service.getProjectileGlowSprite(commonColor), isNotNull);
    expect(service.getImpactSprite(commonColor), isNotNull);
    expect(service.getImpactRingSprite(commonColor), isNotNull);
    expect(service.getEnemyGlowSprite(commonColor), isNotNull);
  });

  testWidgets('ensureColorCached evicts least recently used color', (tester) async {
    final service = SpriteCacheService.instance;
    await service.initialize();

    final colors = List<Color>.generate(
      21,
      (index) => Color(0xFF000000 + index + 1),
    );

    for (final color in colors) {
      await service.ensureColorCached(color);
    }

    final evictedColor = colors.first;
    final retainedColor = colors.last;

    expect(service.getProjectileSprite(evictedColor), isNull);
    expect(service.getProjectileSprite(retainedColor), isNotNull);
  });
}
