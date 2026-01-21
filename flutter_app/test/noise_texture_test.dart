import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/effects/shaders/noise_texture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('NoiseTexture.generate returns image with expected size', () async {
    final image = await NoiseTexture.generate(size: 4, seed: 42);

    expect(image.width, 4);
    expect(image.height, 4);

    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes, isNotNull);
    expect(bytes!.lengthInBytes, 4 * 4 * 4);

    image.dispose();
  });
}
