import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bored_games/src/game/fps/fps_background_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('FpsBackgroundComponent resizes, updates, and renders', () {
    final component = FpsBackgroundComponent();
    final size = Vector2(800, 600);

    component.onGameResize(size);
    expect(component.size.x, 800);
    expect(component.size.y, 600);
    expect(component.position.x, 0);
    expect(component.position.y, 0);

    component.update(0.16);

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    component.render(canvas);
    recorder.endRecording();
  });
}
