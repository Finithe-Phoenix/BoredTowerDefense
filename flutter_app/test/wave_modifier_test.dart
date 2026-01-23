import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/managers/enemy_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WaveModifier enum', () {
    test('has 5 wave modifiers', () {
      expect(WaveModifier.values.length, 5);
    });

    test('normal modifier exists', () {
      expect(WaveModifier.normal, isNotNull);
    });

    test('overload modifier exists', () {
      expect(WaveModifier.overload, isNotNull);
    });

    test('juggernaut modifier exists', () {
      expect(WaveModifier.juggernaut, isNotNull);
    });

    test('mixed modifier exists', () {
      expect(WaveModifier.mixed, isNotNull);
    });

    test('phantom modifier exists', () {
      expect(WaveModifier.phantom, isNotNull);
    });

    test('modifiers can be compared', () {
      expect(WaveModifier.normal == WaveModifier.normal, isTrue);
      expect(WaveModifier.normal == WaveModifier.overload, isFalse);
    });

    test('modifiers have index', () {
      expect(WaveModifier.normal.index, 0);
      expect(WaveModifier.overload.index, 1);
      expect(WaveModifier.juggernaut.index, 2);
      expect(WaveModifier.mixed.index, 3);
      expect(WaveModifier.phantom.index, 4);
    });

    test('modifiers have name', () {
      expect(WaveModifier.normal.name, 'normal');
      expect(WaveModifier.overload.name, 'overload');
      expect(WaveModifier.juggernaut.name, 'juggernaut');
      expect(WaveModifier.mixed.name, 'mixed');
      expect(WaveModifier.phantom.name, 'phantom');
    });
  });
}
