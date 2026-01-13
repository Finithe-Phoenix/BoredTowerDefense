import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/shaders/flag_packer.dart';

void main() {
  test('pack/unpack round trip', () {
    final flags = List<bool>.filled(10, false);
    flags[1] = true;
    flags[3] = true;
    final packed = FlagPacker.pack(flags);
    expect(FlagPacker.unpack(packed, 1), isTrue);
    expect(FlagPacker.unpack(packed, 3), isTrue);
    expect(FlagPacker.unpack(packed, 2), isFalse);
  });

  test('pack only considers first 32 flags', () {
    final flags = List<bool>.generate(40, (index) => index == 31);
    final packed = FlagPacker.pack(flags);
    expect(FlagPacker.unpack(packed, 31), isTrue);
    expect(FlagPacker.unpack(packed, 32), isFalse);
  });

  test('createReader returns a reusable unpacker', () {
    final flags = [true, false, true, false];
    final packed = FlagPacker.pack(flags);
    final reader = FlagPacker.createReader(packed);
    expect(reader(0), isTrue);
    expect(reader(1), isFalse);
    expect(reader(2), isTrue);
  });
}
