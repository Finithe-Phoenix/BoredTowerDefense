import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/data/world_chronicles.dart';

void main() {
  test('chronicles list contains unique world ids', () {
    final ids = allWorldChronicles.map((c) => c.worldId).toList();
    final unique = ids.toSet();
    expect(ids.length, unique.length);
    expect(ids.length, greaterThanOrEqualTo(2));
  });

  test('getChronicleByWorldId returns matching chronicle', () {
    final chronicle = getChronicleByWorldId(1);
    expect(chronicle, isNotNull);
    expect(chronicle?.worldId, 1);
    expect(getChronicleByWorldId(999), isNull);
  });

  test('WorldChronicles exposes list accessor', () {
    final all = WorldChronicles.all;
    expect(all, allWorldChronicles);
    expect(all.isNotEmpty, isTrue);
  });

  test('WorldChronicles.getChronicle proxies lookup', () {
    final chronicle = WorldChronicles.getChronicle(1);
    expect(chronicle, isNotNull);
    expect(chronicle?.worldId, 1);
  });
}
